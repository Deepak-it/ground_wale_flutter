import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/utils/base64_image.dart';
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

  List<Map<String, dynamic>> _academies = <Map<String, dynamic>>[];
  String? _selectedAcademyId;
  List<_StudentItem> _students = <_StudentItem>[];

  String _academyId(Map<String, dynamic> academy) {
    return academy['_id']?.toString() ?? academy['id']?.toString() ?? '';
  }

  DateTime? _parseApiDate(dynamic raw) {
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

  String _shortDateLabel(dynamic raw) {
    final DateTime? date = _parseApiDate(raw);
    if (date == null) {
      return '-';
    }
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day-$month-$year';
  }

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
      final List<Map<String, dynamic>> academies = await GroundWaleApi.instance
          .listAcademies(ownerId);
      String? academyId = _selectedAcademyId;
      if (academyId == null ||
          !academies.any((Map<String, dynamic> item) => _academyId(item) == academyId)) {
        academyId = ApiSession.instance.selectedAcademyId;
      }
      if (academyId == null ||
          !academies.any((Map<String, dynamic> item) => _academyId(item) == academyId)) {
        academyId = academies.isEmpty ? null : _academyId(academies.first);
      }

      final List<dynamic> responses =
          await Future.wait<dynamic>(<Future<dynamic>>[
            GroundWaleApi.instance.listAcademyStudents(
              ownerId,
              limit: 200,
              academyId: academyId,
            ),
            GroundWaleApi.instance.listAcademyBatches(
              ownerId,
              academyId: academyId,
            ),
            GroundWaleApi.instance.listAcademyFees(
              ownerId,
              academyId: academyId,
            ),
            GroundWaleApi.instance.listAcademyAttendance(
              ownerId,
              academyId: academyId,
            ),
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
          _parseApiDate(dayRecord['date']) ??
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
              joiningDate: _shortDateLabel(student['joinDate']),
              paymentMode: latestPaymentModeByStudent[studentId] ?? '-',
              photoBase64: student['photoBase64']?.toString(),
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
        _academies = academies;
        _selectedAcademyId = academyId;
        _students = mapped;
        _isLoading = false;
      });
      ApiSession.instance.setSelectedAcademy(academyId: academyId);
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
              _AcademyDropdown(
                academies: _academies,
                selectedAcademyId: _selectedAcademyId,
                onChanged: (String? value) {
                  if (value == null || value == _selectedAcademyId) {
                    return;
                  }
                  setState(() => _selectedAcademyId = value);
                  ApiSession.instance.setSelectedAcademy(academyId: value);
                  _loadStudents();
                },
              ),
              const SizedBox(height: 12),
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

  Future<void> _showAddPaymentSheet(_StudentItem item) async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty || item.id.isEmpty) {
      return;
    }

    List<Map<String, dynamic>> fees = <Map<String, dynamic>>[];
    try {
      fees = await GroundWaleApi.instance.listAcademyFees(
        ownerId,
        studentId: item.id,
      );
    } catch (_) {}

    final Map<String, dynamic> _foundFee = fees.firstWhere(
      (Map<String, dynamic> f) =>
          (f['status']?.toString() ?? 'pending') != 'paid',
      orElse: () => <String, dynamic>{},
    );
    final Map<String, dynamic>? fee = _foundFee.isEmpty ? null : _foundFee;

    if (!mounted) {
      return;
    }
    if (fee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending fee found for this student')),
      );
      return;
    }

    final double totalAmount =
        (fee['amount'] as num?)?.toDouble() ?? 0;
    final double alreadyPaid =
        (fee['paidAmount'] as num?)?.toDouble() ?? 0;
    final double due =
        (totalAmount - alreadyPaid).clamp(0, double.infinity);
    final String feeId =
        fee['_id']?.toString() ?? fee['id']?.toString() ?? '';

    final TextEditingController amountCtrl = TextEditingController();
    String paymentMode = 'Cash';
    bool isSaving = false;

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext _, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Add Payment — ${item.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Total: Rs ${totalAmount.toStringAsFixed(0)}'  
                    '  •  Paid: Rs ${alreadyPaid.toStringAsFixed(0)}'
                    '  •  Due: Rs ${due.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF9FB9B3),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Amount Paying Now',
                    style: TextStyle(
                      color: Color(0xFFE6F7F4),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x1FFFFFFF)),
                      color: const Color(0x0FFFFFFF),
                    ),
                    child: TextField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter amount',
                        hintStyle: TextStyle(color: Color(0x99FFFFFF)),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Payment Mode',
                    style: TextStyle(
                      color: Color(0xFFE6F7F4),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <String>['Cash', 'UPI', 'Card']
                        .map((String mode) {
                          final bool sel = paymentMode == mode;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () =>
                                    setSheetState(() => paymentMode = mode),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: sel
                                          ? const Color(0xFF00C9A7)
                                          : const Color(0x1FFFFFFF),
                                    ),
                                    color: sel
                                        ? const Color(0x1400C9A7)
                                        : const Color(0x0FFFFFFF),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    mode,
                                    style: TextStyle(
                                      color: sel
                                          ? const Color(0xFF00C9A7)
                                          : Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        })
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final double paying = double.tryParse(
                                    amountCtrl.text.replaceAll(
                                      RegExp(r'[^0-9.]'),
                                      '',
                                    ),
                                  ) ??
                                  0;
                              if (paying <= 0) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Enter a valid amount'),
                                  ),
                                );
                                return;
                              }
                              setSheetState(() => isSaving = true);
                              try {
                                final double newPaid =
                                    (alreadyPaid + paying).clamp(
                                      0,
                                      totalAmount,
                                    );
                                final String newStatus =
                                    newPaid >= totalAmount
                                        ? 'paid'
                                        : 'partial';
                                await GroundWaleApi.instance
                                    .updateAcademyFee(
                                      ownerId,
                                      feeId,
                                      <String, dynamic>{
                                        'paidAmount': newPaid,
                                        'status': newStatus,
                                        'paymentMode': paymentMode,
                                      },
                                    );
                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop();
                                }
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Payment recorded'),
                                    ),
                                  );
                                  await _loadStudents();
                                }
                              } catch (error) {
                                setSheetState(() => isSaving = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        error
                                            .toString()
                                            .replaceFirst('Exception: ', ''),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C9A7),
                        foregroundColor: const Color(0xFF1D1D1D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1D1D1D),
                              ),
                            )
                          : const Text(
                              'Save Payment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    amountCtrl.dispose();
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
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAddPaymentSheet(item);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0x1F242424)),
                    ),
                    child: const Text(
                      'Add Payment',
                      style: TextStyle(
                        color: Color(0xFF00874D),
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

class _AcademyDropdown extends StatelessWidget {
  const _AcademyDropdown({
    required this.academies,
    required this.selectedAcademyId,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> academies;
  final String? selectedAcademyId;
  final ValueChanged<String?> onChanged;

  String _academyId(Map<String, dynamic> academy) {
    return academy['_id']?.toString() ?? academy['id']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> options = academies
        .map((Map<String, dynamic> academy) => <String, String>{
              'id': _academyId(academy),
              'name': academy['name']?.toString() ?? 'Academy',
            })
        .where((Map<String, String> academy) => academy['id']!.isNotEmpty)
        .toList();

    final String? normalizedValue = options.any(
      (Map<String, String> item) => item['id'] == selectedAcademyId,
    )
        ? selectedAcademyId
        : null;

    return DropdownButtonFormField<String>(
      initialValue: normalizedValue,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0x99FFFFFF),
      ),
      dropdownColor: const Color(0xFF203A43),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: 'Select Academy',
        labelStyle: const TextStyle(color: Color(0xB3E6F7F4), fontSize: 13),
        isDense: true,
        filled: true,
        fillColor: const Color(0x0FFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0x33FFFFFF)),
        ),
      ),
      items: options.map((Map<String, String> item) {
        return DropdownMenuItem<String>(
          value: item['id'],
          child: Text(item['name']!, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: onChanged,
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
    this.photoBase64,
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
  final String? photoBase64;
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
              clipBehavior: Clip.antiAlias,
              child: _buildAvatar(item.photoBase64, item.name, 52, 18),
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

  Widget _buildAvatar(String? photoBase64, String name, double size, double fontSize) {
    final Uint8List? bytes = decodeBase64ImageBytes(photoBase64);
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover, width: size, height: size);
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: TextStyle(
          color: const Color(0xFFE6F7F4),
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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


