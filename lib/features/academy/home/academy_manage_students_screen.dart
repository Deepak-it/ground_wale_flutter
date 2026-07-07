import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import 'academy_add_student_screen.dart';
import 'academy_edit_student_screen.dart';
import 'academy_student_details_screen.dart';

class AcademyManageStudentsScreen extends StatefulWidget {
  const AcademyManageStudentsScreen({super.key});

  @override
  State<AcademyManageStudentsScreen> createState() =>
      _AcademyManageStudentsScreenState();
}

class _AcademyManageStudentsScreenState
    extends State<AcademyManageStudentsScreen> {
  int _selectedTab = 0;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  List<_StudentItem> _students = <_StudentItem>[];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _students = <_StudentItem>[];
        });
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final List<dynamic> responses =
          await Future.wait<dynamic>(<Future<dynamic>>[
            GroundWaleApi.instance.listAcademyStudents(ownerId, limit: 200),
            GroundWaleApi.instance.listAcademyBatches(ownerId),
            GroundWaleApi.instance.listAcademyFees(ownerId),
            GroundWaleApi.instance.listAcademyAttendance(ownerId),
          ]);

      final Map<String, dynamic> studentResponse =
          responses[0] as Map<String, dynamic>;
      final List<Map<String, dynamic>> batches =
          responses[1] as List<Map<String, dynamic>>;
      final List<Map<String, dynamic>> fees =
          responses[2] as List<Map<String, dynamic>>;
      final List<Map<String, dynamic>> attendance =
          responses[3] as List<Map<String, dynamic>>;

      final Map<String, String> batchById = <String, String>{
        for (final Map<String, dynamic> batch in batches)
          (batch['_id']?.toString() ?? ''): batch['name']?.toString() ?? '',
      };

      final Map<String, String> latestFeeByStudent = <String, String>{};
      final Map<String, String> latestFeeAmountByStudent = <String, String>{};
      final Map<String, String> latestPaymentModeByStudent = <String, String>{};
      for (final Map<String, dynamic> fee in fees) {
        final String studentId =
            (fee['studentId'] is Map<String, dynamic>
                    ? (fee['studentId'] as Map<String, dynamic>)['_id']
                    : fee['studentId'])
                ?.toString() ??
            '';
        if (studentId.isEmpty || latestFeeByStudent.containsKey(studentId)) {
          continue;
        }
        final String status = fee['status']?.toString() ?? 'pending';
        latestFeeByStudent[studentId] = status.toLowerCase() == 'paid'
            ? 'Paid'
            : 'Pending';
        latestFeeAmountByStudent[studentId] =
            (fee['amount'] as num?)?.toString() ??
            (fee['paidAmount'] as num?)?.toString() ??
            '';
        latestPaymentModeByStudent[studentId] =
            fee['paymentMode']?.toString() ?? '';
      }

      final Map<String, DateTime> latestAttendanceDateByStudent =
          <String, DateTime>{};
      final Map<String, String> latestAttendanceByStudent = <String, String>{};
      for (final Map<String, dynamic> dayRecord in attendance) {
        final DateTime dayDate =
            DateTime.tryParse(dayRecord['date']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final List<dynamic> entries =
            dayRecord['entries'] as List<dynamic>? ?? <dynamic>[];

        for (final dynamic rawEntry in entries) {
          if (rawEntry is! Map) {
            continue;
          }
          final Map<String, dynamic> entry = Map<String, dynamic>.from(
            rawEntry,
          );
          final dynamic studentRef = entry['studentId'];
          final String studentId = studentRef is Map<String, dynamic>
              ? studentRef['_id']?.toString() ?? ''
              : studentRef?.toString() ?? '';
          if (studentId.isEmpty) {
            continue;
          }

          final DateTime? prevDate = latestAttendanceDateByStudent[studentId];
          if (prevDate != null && prevDate.isAfter(dayDate)) {
            continue;
          }

          final String rawStatus =
              entry['status']?.toString().toLowerCase().trim() ?? '';
          latestAttendanceDateByStudent[studentId] = dayDate;
          latestAttendanceByStudent[studentId] = rawStatus == 'present'
              ? 'Present'
              : rawStatus == 'absent'
              ? 'Absent'
              : 'Leave';
        }
      }

      final List<dynamic> itemsRaw =
          studentResponse['items'] as List<dynamic>? ?? <dynamic>[];
      List<_StudentItem> mapped = itemsRaw
          .map((dynamic raw) => Map<String, dynamic>.from(raw as Map))
          .map((Map<String, dynamic> student) {
            final String studentId = student['_id']?.toString() ?? '';
            final String batchId = student['batchId']?.toString() ?? '';
            return _StudentItem(
              id: studentId,
              name: student['fullName']?.toString() ?? 'Student',
              phone: student['phone']?.toString() ?? '',
              batchId: batchId,
              batch: batchById[batchId] ?? 'Unassigned Batch',
              attendance: latestAttendanceByStudent[studentId] ?? 'Unmarked',
              fee: latestFeeByStudent[studentId] ?? 'Pending',
              feesAmount:
                  latestFeeAmountByStudent[studentId] ??
                  (student['monthlyFee'] as num?)?.toString() ??
                  '-',
              joiningDate:
                  student['joinDate']?.toString().split('T').first ?? '-',
              paymentMode: latestPaymentModeByStudent[studentId] ?? '-',
            );
          })
          .toList();

      if (_selectedTab == 1) {
        mapped = mapped
            .where((final _StudentItem item) => item.fee == 'Paid')
            .toList();
      } else if (_selectedTab == 2) {
        mapped = mapped
            .where((final _StudentItem item) => item.fee == 'Pending')
            .toList();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _students = mapped;
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

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim().toLowerCase();
    final List<_StudentItem> filteredStudents = query.isEmpty
        ? _students
        : _students.where((final _StudentItem item) {
            return item.name.toLowerCase().contains(query) ||
                item.batch.toLowerCase().contains(query) ||
                item.phone.toLowerCase().contains(query);
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: SingleChildScrollView(
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
                  const Text(
                    'Manage Students',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x1FFFFFFF)),
                  color: const Color(0x0FFFFFFF),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0x99FFFFFF),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'Search students...',
                          hintStyle: TextStyle(
                            color: Color(0x99FFFFFF),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0x99FFFFFF),
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  _tabButton(index: 0, label: 'All'),
                  const SizedBox(width: 12),
                  _tabButton(index: 1, label: 'Paid'),
                  const SizedBox(width: 12),
                  _tabButton(index: 2, label: 'Pending'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const <Widget>[
                  Text(
                    'Students',
                    style: TextStyle(
                      color: Color(0xFFE6F7F4),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Tap a student to view details',
                    style: TextStyle(
                      color: Color(0x99E6F7F4),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final bool? created = await Navigator.of(context)
                        .push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => const AcademyAddStudentScreen(),
                          ),
                        );
                    if (created == true && mounted) {
                      await _loadStudents();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C9A7),
                    foregroundColor: const Color(0xFF1D1D1D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Student',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
                )
              else if (filteredStudents.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      query.isEmpty
                          ? 'No students found'
                          : 'No matching students',
                      style: const TextStyle(
                        color: Color(0x99E6F7F4),
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                ...filteredStudents.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _StudentCard(
                      item: item,
                      onTap: () => _openStudentDetails(item),
                      onMoreTap: () => _showStudentOptionsSheet(item),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openStudentDetails(_StudentItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AcademyStudentDetailsScreen(
          studentId: item.id,
          studentName: item.name,
          batchName: item.batch,
          attendanceStatus: item.attendance,
          feeStatus: item.fee,
        ),
      ),
    );
  }

  void _openEditStudent(_StudentItem item) {
    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => AcademyEditStudentScreen(
              studentId: item.id,
              studentName: item.name,
              batchName: item.batch,
              feeStatus: item.fee,
              phoneNumber: item.phone,
              feesAmount: item.feesAmount,
              joiningDate: item.joiningDate,
              paymentMode: item.paymentMode,
            ),
          ),
        )
        .then((bool? updated) {
          if (updated == true && mounted) {
            _loadStudents();
          }
        });
  }

  Future<void> _deleteStudent(_StudentItem item) async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }
    if (item.id.isEmpty) {
      return;
    }
    try {
      await GroundWaleApi.instance.deleteAcademyStudent(ownerId, item.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Student deleted')));
      await _loadStudents();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  void _showStudentOptionsSheet(_StudentItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99242424),
      builder: (BuildContext context) {
        return SafeArea(
          top: false,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Options',
                      style: TextStyle(
                        color: Color(0xFF313638),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF242424),
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    _openEditStudent(item);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      border: Border.all(color: const Color(0x1F242424)),
                    ),
                    child: const Text(
                      'Edit Student',
                      style: TextStyle(
                        color: Color(0xFF242424),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _deleteStudent(item);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                      border: Border.all(color: const Color(0x1F242424)),
                    ),
                    child: const Text(
                      'Delete Student',
                      style: TextStyle(
                        color: Color(0xFFE3220D),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tabButton({required int index, required String label}) {
    final bool selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = index);
          _loadStudents();
        },
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x1FFFFFFF)),
            color: selected ? const Color(0xFF00C9A7) : const Color(0x0FFFFFFF),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF242424) : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentItem {
  const _StudentItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.batchId,
    required this.batch,
    required this.attendance,
    required this.fee,
    required this.feesAmount,
    required this.joiningDate,
    required this.paymentMode,
  });

  final String id;
  final String name;
  final String phone;
  final String batchId;
  final String batch;
  final String attendance;
  final String fee;
  final String feesAmount;
  final String joiningDate;
  final String paymentMode;
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.item,
    required this.onTap,
    required this.onMoreTap,
  });

  final _StudentItem item;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    final String attendance = item.attendance;
    final bool present = attendance == 'Present';
    final bool absent = attendance == 'Absent';
    final bool paid = item.fee == 'Paid';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          color: const Color(0x0FFFFFFF),
        ),
        child: Row(
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
                _initials(item.name),
                style: const TextStyle(
                  color: Color(0xFFE6F7F4),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Color(0xFFE6F7F4),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.batch,
                    style: const TextStyle(
                      color: Color(0x99E6F7F4),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: <Widget>[
                      _Badge(
                        label: attendance,
                        textColor: present
                            ? const Color(0xFF00C9A7)
                            : absent
                            ? const Color(0xFFE3220D)
                            : const Color(0xFFF59E0B),
                        background: present
                            ? const Color(0x1F00C9A7)
                            : absent
                            ? const Color(0x1FE3220D)
                            : const Color(0x1FF59E0B),
                      ),
                      const SizedBox(width: 6),
                      _Badge(
                        label: item.fee,
                        textColor: paid
                            ? const Color(0xFF08B36A)
                            : const Color(0xFFF59E0B),
                        background: paid
                            ? const Color(0x1F08B36A)
                            : const Color(0x1FF59E0B),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: onMoreTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0x08FFFFFF),
                ),
                child: const Icon(Icons.more_vert_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final List<String> p = name.split(' ');
    if (p.length == 1) {
      return p.first.substring(0, p.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${p.first[0]}${p.last[0]}'.toUpperCase();
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.textColor,
    required this.background,
  });

  final String label;
  final Color textColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: background,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}


