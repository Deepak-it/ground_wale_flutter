import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class AcademyFeeDetailsScreen extends StatefulWidget {
  const AcademyFeeDetailsScreen({super.key});

  @override
  State<AcademyFeeDetailsScreen> createState() =>
      _AcademyFeeDetailsScreenState();
}

class _AcademyFeeDetailsScreenState extends State<AcademyFeeDetailsScreen> {
  bool _isLoading = true;
  bool _isSendingBulkReminder = false;
  String _status = 'All';
  List<Map<String, dynamic>> _academies = <Map<String, dynamic>>[];
  String? _selectedAcademyId;
  String? _selectedBatchId;

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _batches = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _students = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _allFees = <Map<String, dynamic>>[];
  final Set<String> _selectedReminderFeeIds = <String>{};
  String _reminderChannel = 'WhatsApp';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? get _ownerId => ApiSession.instance.ownerId;

  Map<String, dynamic> _safeStringMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      final Map<String, dynamic> result = <String, dynamic>{};
      value.forEach((dynamic key, dynamic item) {
        if (key == null) {
          return;
        }
        result[key.toString()] = item;
      });
      return result;
    }
    return <String, dynamic>{};
  }

  String _batchId(Map<String, dynamic> batch) {
    return batch['_id']?.toString() ?? batch['id']?.toString() ?? '';
  }

  String _academyId(Map<String, dynamic> academy) {
    return academy['_id']?.toString() ?? academy['id']?.toString() ?? '';
  }

  String _studentId(Map<String, dynamic> student) {
    return student['_id']?.toString() ?? student['id']?.toString() ?? '';
  }

  String _studentName(Map<String, dynamic> student) {
    return student['fullName']?.toString().trim().isNotEmpty == true
        ? student['fullName']?.toString() ?? 'Student'
        : 'Student';
  }

  String _feeId(Map<String, dynamic> fee) {
    return fee['_id']?.toString() ?? fee['id']?.toString() ?? '';
  }

  String _feeStatus(Map<String, dynamic> fee) {
    final String value =
        fee['status']?.toString().trim().toLowerCase() ?? 'pending';
    if (value == 'paid' || value == 'partial' || value == 'pending') {
      return value;
    }
    return 'pending';
  }

  Map<String, dynamic> _studentFromFee(Map<String, dynamic> fee) {
    return _safeStringMap(fee['studentId']);
  }

  String _studentIdFromFee(Map<String, dynamic> fee) {
    final dynamic studentRaw = fee['studentId'];
    if (studentRaw is Map) {
      final Map<String, dynamic> student = _safeStringMap(studentRaw);
      return _studentId(student);
    }
    if (studentRaw is String) {
      return studentRaw;
    }
    return '';
  }

  Map<String, dynamic>? _findStudent(String studentId) {
    for (final Map<String, dynamic> student in _students) {
      if (_studentId(student) == studentId) {
        return student;
      }
    }
    return null;
  }

  String _studentBatchName(String studentId) {
    final Map<String, dynamic>? student = _findStudent(studentId);
    if (student == null) {
      return '-';
    }
    final String name = student['batchName']?.toString().trim() ?? '';
    if (name.isNotEmpty) {
      return name;
    }
    return '-';
  }

  Future<void> _load() async {
    final String? ownerId = _ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
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

      final List<Map<String, dynamic>> batches = await GroundWaleApi.instance
          .listAcademyBatches(ownerId, academyId: academyId);
      final Map<String, dynamic> studentsResponse = await GroundWaleApi.instance
          .listAcademyStudents(ownerId, limit: 500, academyId: academyId);
      final List<dynamic> studentItems =
          studentsResponse['items'] as List<dynamic>? ?? <dynamic>[];
      final List<Map<String, dynamic>> students = studentItems
          .whereType<Map>()
          .map((Map item) => _safeStringMap(item))
          .toList();
      final List<Map<String, dynamic>> fees = await GroundWaleApi.instance
          .listAcademyFees(ownerId, academyId: academyId);

      if (!mounted) {
        return;
      }

      setState(() {
        _academies = academies;
        _selectedAcademyId = academyId;
        _batches = batches;
        if (_selectedBatchId == null && _batches.isNotEmpty) {
          _selectedBatchId = _batchId(_batches.first);
        }
        _students = students;
        _allFees = fees;
        _selectedReminderFeeIds.removeWhere((String id) {
          return !_allFees.any((Map<String, dynamic> fee) => _feeId(fee) == id);
        });
        _isLoading = false;
      });
      ApiSession.instance.setSelectedAcademy(academyId: academyId);
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

  List<Map<String, dynamic>> _batchScopedFees() {
    if (_selectedBatchId == null || _selectedBatchId!.isEmpty) {
      return List<Map<String, dynamic>>.from(_allFees);
    }

    final Set<String> selectedStudentIds = _students
        .where((Map<String, dynamic> student) {
          final String batchId =
              student['batchId']?.toString() ??
              student['batch']?.toString() ??
              '';
          return batchId == _selectedBatchId;
        })
        .map(_studentId)
        .where((String id) => id.isNotEmpty)
        .toSet();

    return _allFees.where((Map<String, dynamic> fee) {
      final String studentId = _studentIdFromFee(fee);
      return selectedStudentIds.contains(studentId);
    }).toList();
  }

  List<Map<String, dynamic>> _visibleFees() {
    final String query = _searchController.text.trim().toLowerCase();
    return _batchScopedFees().where((Map<String, dynamic> fee) {
      final String status = _feeStatus(fee);
      final bool matchesStatus = _status == 'All'
          ? true
          : status == _status.toLowerCase();
      if (!matchesStatus) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }

      final Map<String, dynamic> student = _studentFromFee(fee);
      final String fullName = _studentName(student).toLowerCase();
      final String monthKey = fee['monthKey']?.toString().toLowerCase() ?? '';
      return fullName.contains(query) || monthKey.contains(query);
    }).toList();
  }

  double _amount(Map<String, dynamic> fee) {
    return (fee['amount'] as num?)?.toDouble() ?? 0;
  }

  double _paidAmount(Map<String, dynamic> fee) {
    return (fee['paidAmount'] as num?)?.toDouble() ?? 0;
  }

  Future<void> _sendSingleReminder(String feeId) async {
    if (feeId.isEmpty) {
      return;
    }
    await _openSendReminderDialog(feeIds: <String>[feeId]);
  }

  Future<void> _sendBulkReminder(List<String> feeIds) async {
    final String? ownerId = _ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }
    final List<String> selected = feeIds;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one pending fee')),
      );
      return;
    }

    setState(() => _isSendingBulkReminder = true);
    int sent = 0;
    try {
      for (final String feeId in selected) {
        await GroundWaleApi.instance.sendAcademyFeeReminder(ownerId, feeId);
        sent++;
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reminder sent via $_reminderChannel to $sent students',
          ),
        ),
      );
      await _load();
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
        setState(() => _isSendingBulkReminder = false);
      }
    }
  }

  Future<void> _openSendReminderDialog({required List<String> feeIds}) async {
    if (feeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one pending fee')),
      );
      return;
    }

    Map<String, dynamic>? firstFee;
    for (final String id in feeIds) {
      final int index = _allFees.indexWhere(
        (Map<String, dynamic> fee) => _feeId(fee) == id,
      );
      if (index >= 0) {
        firstFee = _allFees[index];
        break;
      }
    }

    final Map<String, dynamic> previewFee = firstFee ?? <String, dynamic>{};
    final Map<String, dynamic> previewStudent = _studentFromFee(previewFee);
    final String previewStudentName = _studentName(previewStudent);
    final String previewStudentId = _studentIdFromFee(previewFee);
    final String previewBatch = _studentBatchName(previewStudentId);
    final String message =
        'Hi $previewStudentName, your fee of ${_currency(_amount(previewFee))} '
        'for $previewBatch batch is pending. Please pay at the earliest.';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99242424),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'Send Reminder',
                          style: TextStyle(
                            color: Color(0xFF313638),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF242424),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Message Review',
                      style: TextStyle(
                        color: Color(0xFF242424),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
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
                        border: Border.all(color: const Color(0x3D242424)),
                        color: const Color(0x0FFFFFFF),
                      ),
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Color(0xFF242424),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _channelTile(
                            label: 'Whatsapp',
                            icon: Icons.chat,
                            selected: _reminderChannel == 'WhatsApp',
                            onTap: () {
                              setSheetState(
                                () => _reminderChannel = 'WhatsApp',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _channelTile(
                            label: 'SMS',
                            icon: Icons.sms,
                            selected: _reminderChannel == 'SMS',
                            onTap: () {
                              setSheetState(() => _reminderChannel = 'SMS');
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSendingBulkReminder
                            ? null
                            : () async {
                                Navigator.of(context).pop();
                                await _sendBulkReminder(feeIds);
                              },
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Color(0xFF242424),
                        ),
                        label: Text(
                          feeIds.length == 1
                              ? 'Send Reminder'
                              : 'Send Reminder (${feeIds.length})',
                          style: const TextStyle(
                            color: Color(0xFF1D1D1D),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C9A7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddPaymentSheet(Map<String, dynamic> fee) async {
    final String? ownerId = _ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    final double totalAmount = _amount(fee);
    final double alreadyPaid = _paidAmount(fee);
    final double due = (totalAmount - alreadyPaid).clamp(0, double.infinity);
    final String feeId = _feeId(fee);
    if (feeId.isEmpty) {
      return;
    }

    final TextEditingController amountCtrl = TextEditingController();
    String paymentMode = 'Cash';
    bool isSaving = false;

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
                      const Text(
                        'Add Payment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
                    'Total: ${_currency(totalAmount)}'
                    '  •  Paid: ${_currency(alreadyPaid)}'
                    '  •  Due: ${_currency(due)}',
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
                                    newPaid >= totalAmount ? 'paid' : 'partial';
                                await GroundWaleApi.instance.updateAcademyFee(
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
                                  await _load();
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

  Widget _channelTile({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF00C9A7) : const Color(0x1F242424),
          ),
          color: Colors.white,
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, size: 44, color: const Color(0xFF16B0E2)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF242424),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSelectedFee(Map<String, dynamic> fee) {
    final String feeId = _feeId(fee);
    if (feeId.isEmpty || _feeStatus(fee) == 'paid') {
      return;
    }
    setState(() {
      if (_selectedReminderFeeIds.contains(feeId)) {
        _selectedReminderFeeIds.remove(feeId);
      } else {
        _selectedReminderFeeIds.add(feeId);
      }
    });
  }

  String _statusLabel(String status) {
    if (status.isEmpty) {
      return 'Pending';
    }
    return '${status.substring(0, 1).toUpperCase()}${status.substring(1)}';
  }

  String _currency(double value) {
    return 'Rs ${value.toStringAsFixed(0)}';
  }

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

  String _fmtExpiry(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final DateTime? d = DateTime.tryParse(raw);
    if (d == null) return raw;
    final DateTime local = d.toLocal();
    const List<String> months = <String>[
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  bool _isExpiredStr(String? raw) {
    if (raw == null || raw.isEmpty) return false;
    final DateTime? d = DateTime.tryParse(raw);
    if (d == null) return false;
    return d.isBefore(DateTime.now());
  }

  void _openFeeDetails(Map<String, dynamic> fee) {
    final Map<String, dynamic> student = _studentFromFee(fee);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF17313A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _studentName(student),
                  style: const TextStyle(
                    color: Color(0xFFE6F7F4),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Month: ${fee['monthKey'] ?? '-'}',
                  style: const TextStyle(color: Color(0xFF9FB9B3)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Status: ${_statusLabel(_feeStatus(fee)).toUpperCase()}',
                  style: const TextStyle(color: Color(0xFF9FB9B3)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Amount: ${_currency(_amount(fee))}',
                  style: const TextStyle(color: Color(0xFF9FB9B3)),
                ),
                const SizedBox(height: 6),
                Text(
                  'Paid: ${_currency(_paidAmount(fee))}',
                  style: const TextStyle(color: Color(0xFF9FB9B3)),
                ),
                const SizedBox(height: 14),
                if (_feeStatus(fee) != 'paid')
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await _sendSingleReminder(_feeId(fee));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C9A7),
                        foregroundColor: const Color(0xFF1D1D1D),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Send Reminder'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> batchFees = _batchScopedFees();
    final List<Map<String, dynamic>> visibleFees = _visibleFees();

    final double total = batchFees.fold<double>(
      0,
      (double s, Map<String, dynamic> f) => s + _amount(f),
    );
    final double paid = batchFees.fold<double>(
      0,
      (double s, Map<String, dynamic> f) => s + _paidAmount(f),
    );
    final double pending = (total - paid).clamp(0, double.infinity);
    final int paidStudents = batchFees
        .where((Map<String, dynamic> fee) => _feeStatus(fee) == 'paid')
        .length;
    final int pendingStudents = batchFees.length - paidStudents;
    final double collectionRate = total <= 0 ? 0 : (paid / total).clamp(0, 1);

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C9A7)),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
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
                      const Expanded(
                        child: Text(
                          'Fees Collection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAcademyId,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0x99FFFFFF),
                    ),
                    dropdownColor: const Color(0xFF203A43),
                    decoration: InputDecoration(
                      labelText: 'Select Academy',
                      labelStyle: const TextStyle(
                        color: Color(0xB3E6F7F4),
                        fontSize: 13,
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0x0FFFFFFF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0x1FFFFFFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
                      ),
                    ),
                    items: _academies.map((Map<String, dynamic> academy) {
                      final String id = _academyId(academy);
                      final String name = academy['name']?.toString() ?? 'Academy';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(
                          name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value == null || value == _selectedAcademyId) {
                        return;
                      }
                      setState(() {
                        _selectedAcademyId = value;
                        _selectedBatchId = null;
                        _selectedReminderFeeIds.clear();
                      });
                      ApiSession.instance.setSelectedAcademy(academyId: value);
                      _load();
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_batches.isNotEmpty)
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _batches.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 12),
                        itemBuilder: (BuildContext context, int index) {
                          final Map<String, dynamic> batch = _batches[index];
                          final String batchId = _batchId(batch);
                          final bool selected = batchId == _selectedBatchId;
                          return InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (batchId.isEmpty || selected) {
                                return;
                              }
                              setState(() {
                                _selectedBatchId = batchId;
                                _selectedReminderFeeIds.clear();
                              });
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
                    children: <Widget>[
                      Expanded(
                        child: _summary(
                          'Total Collection',
                          _currency(total),
                          footnote: 'This Month',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summary(
                          'Pending Amount',
                          _currency(pending),
                          valueColor: const Color(0xFFF59E0B),
                          footnote:
                              '$pendingStudents ${pendingStudents == 1 ? 'Student' : 'Students'}',
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
                      border: Border.all(color: const Color(0x1FFFFFFF)),
                      color: const Color(0x0FFFFFFF),
                    ),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text(
                              'Collection Rate',
                              style: TextStyle(
                                color: Color(0xFFE6F7F4),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(collectionRate * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Color(0xFF08B36A),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: LinearProgressIndicator(
                            value: collectionRate,
                            backgroundColor: const Color(0xFFF2F6F9),
                            color: const Color(0xFF22C55E),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              '$paidStudents Paid',
                              style: const TextStyle(
                                color: Color(0xFF08B36A),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '$pendingStudents Pending',
                              style: const TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppTextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search students....',
                              hintStyle: TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        if (_searchController.text.trim().isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0x99FFFFFF),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ['All', 'Paid', 'Pending'].map((String item) {
                      final bool selected = _status == item;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: item == 'Pending' ? 0 : 8,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _status = item),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0x1FFFFFFF),
                                ),
                                color: selected
                                    ? const Color(0xFF00C9A7)
                                    : const Color(0x0FFFFFFF),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                item,
                                style: TextStyle(
                                  color: selected
                                      ? const Color(0xFF242424)
                                      : const Color(0x99FFFFFF),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  if (visibleFees.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x1FFFFFFF)),
                        color: const Color(0x0FFFFFFF),
                      ),
                      child: const Center(
                        child: Text(
                          'No fee records found',
                          style: TextStyle(color: Color(0x99FFFFFF)),
                        ),
                      ),
                    ),
                  if (visibleFees.isNotEmpty)
                    ...visibleFees.map((Map<String, dynamic> fee) {
                      final Map<String, dynamic> student = _studentFromFee(fee);
                      final String studentName = _studentName(student);
                      final String batchName = _studentBatchName(
                        _studentIdFromFee(fee),
                      );
                      final String status = _feeStatus(fee);
                      final String feeId = _feeId(fee);
                      final bool selectedForReminder = _selectedReminderFeeIds
                          .contains(feeId);

                      final bool allowSelection = status != 'paid';

                      final Color tagBg = status == 'paid'
                          ? const Color(0x1F08B36A)
                          : status == 'partial'
                          ? const Color(0x1FF59E0B)
                          : const Color(0x35F59E0B);

                      final Color tagFg = status == 'paid'
                          ? const Color(0xFF08B36A)
                          : const Color(0xFFF59E0B);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x1FFFFFFF)),
                          color: const Color(0x0AFFFFFF),
                        ),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                if (allowSelection)
                                  GestureDetector(
                                    onTap: () => _toggleSelectedFee(fee),
                                    child: Icon(
                                      selectedForReminder
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      color: selectedForReminder
                                          ? const Color(0xFF00C9A7)
                                          : const Color(0x80FFFFFF),
                                    ),
                                  ),
                                if (allowSelection) const SizedBox(width: 12),
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                    color: const Color(0x1AFFFFFF),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _initials(studentName),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        studentName,
                                        style: const TextStyle(
                                          color: Color(0xFFE6F7F4),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        batchName,
                                        style: const TextStyle(
                                          color: Color(0x99E6F7F4),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: tagBg,
                                      ),
                                      child: Text(
                                        _statusLabel(status),
                                        style: TextStyle(
                                          color: tagFg,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${_currency(_paidAmount(fee))} / ${_currency(_amount(fee))}',
                                      style: const TextStyle(
                                        color: Color(0x99FFFFFF),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      "Month: ${fee['monthKey'] ?? '-'}",
                                      style: const TextStyle(
                                        color: Color(0x99FFFFFF),
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (fee['subscriptionEndDate'] != null) ...<Widget>[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Expires: ${_fmtExpiry(fee['subscriptionEndDate']?.toString())}',
                                        style: TextStyle(
                                          color: _isExpiredStr(fee['subscriptionEndDate']?.toString())
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF9FB9B3),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    if (status != 'paid')
                                      TextButton(
                                        onPressed: () =>
                                            _showAddPaymentSheet(fee),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF22C55E),
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text('Add Payment'),
                                      ),
                                    if (status != 'paid')
                                      const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () => _openFeeDetails(fee),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF00C9A7),
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('View Details'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  if (visibleFees.isNotEmpty)
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF00C9A7),
                        ),
                        child: const Text('View all Students'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSendingBulkReminder
                          ? null
                          : () => _openSendReminderDialog(
                              feeIds: _selectedReminderFeeIds.toList(),
                            ),
                      icon: _isSendingBulkReminder
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF1D1D1D),
                              ),
                            )
                          : const Icon(
                              Icons.notifications_outlined,
                              color: Color(0xFF242424),
                            ),
                      label: Text(
                        _isSendingBulkReminder
                            ? 'Sending...'
                            : _selectedReminderFeeIds.isEmpty
                            ? 'Send Reminder'
                            : 'Send Reminder (${_selectedReminderFeeIds.length})',
                        style: const TextStyle(
                          color: Color(0xFF1D1D1D),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C9A7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _summary(
    String title,
    String value, {
    Color valueColor = const Color(0xFFE6F7F4),
    String? footnote,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0FFFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
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
          if (footnote != null && footnote.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: const Color(0x08FFFFFF),
              ),
              child: Text(
                footnote,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


