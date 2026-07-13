import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class AcademyEditStudentScreen extends StatefulWidget {
  const AcademyEditStudentScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.batchName,
    required this.feeStatus,
    required this.phoneNumber,
    required this.feesAmount,
    required this.joiningDate,
    required this.paymentMode,
  });

  final String studentId;
  final String studentName;
  final String batchName;
  final String feeStatus;
  final String phoneNumber;
  final String feesAmount;
  final String joiningDate;
  final String paymentMode;

  @override
  State<AcademyEditStudentScreen> createState() =>
      _AcademyEditStudentScreenState();
}

class _AcademyEditStudentScreenState extends State<AcademyEditStudentScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _batchController;
  late final TextEditingController _feesController;
  late final TextEditingController _joiningDateController;

  late String _feeStatus;
  late String _paymentMode;
  bool _isSaving = false;
  List<Map<String, dynamic>> _academies = <Map<String, dynamic>>[];
  String? _selectedAcademyId;
  List<Map<String, dynamic>> _batches = <Map<String, dynamic>>[];
  String? _selectedBatchId;

  String _academyId(Map<String, dynamic> academy) {
    return academy['_id']?.toString() ?? academy['id']?.toString() ?? '';
  }

  String _batchId(Map<String, dynamic> batch) {
    return batch['_id']?.toString() ?? batch['id']?.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.studentName);
    _phoneController = TextEditingController(text: widget.phoneNumber);
    _batchController = TextEditingController(text: widget.batchName);
    _feesController = TextEditingController(text: widget.feesAmount);
    _joiningDateController = TextEditingController(text: widget.joiningDate);
    _feeStatus = widget.feeStatus == 'Pending' ? 'Pending' : 'Paid';
    _paymentMode = widget.paymentMode;
    _loadAcademiesAndBatches();
  }

  Future<void> _loadAcademiesAndBatches() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }
    try {
      final List<Map<String, dynamic>> academies = await GroundWaleApi.instance
          .listAcademies(ownerId);
      final Map<String, dynamic> student = await GroundWaleApi.instance
          .getAcademyStudent(ownerId, widget.studentId);
      final String? studentAcademyId = student['academyId']?.toString();
      String? selectedAcademyId = studentAcademyId;
      if (selectedAcademyId == null ||
          selectedAcademyId.isEmpty ||
          !academies.any(
            (Map<String, dynamic> academy) =>
                _academyId(academy) == selectedAcademyId,
          )) {
        selectedAcademyId = ApiSession.instance.selectedAcademyId;
      }
      if (selectedAcademyId == null ||
          selectedAcademyId.isEmpty ||
          !academies.any(
            (Map<String, dynamic> academy) =>
                _academyId(academy) == selectedAcademyId,
          )) {
        selectedAcademyId = academies.isEmpty ? null : _academyId(academies.first);
      }

      final List<Map<String, dynamic>> batches = await GroundWaleApi.instance
          .listAcademyBatches(ownerId, academyId: selectedAcademyId);
      if (!mounted) {
        return;
      }
      setState(() {
        _academies = academies;
        _selectedAcademyId = selectedAcademyId;
        _batches = batches;
        final String? studentBatchId = student['batchId']?.toString();
        final Map<String, dynamic> matched = batches.firstWhere(
          (Map<String, dynamic> item) =>
              _batchId(item) == studentBatchId ||
              (item['name']?.toString() ?? '').toLowerCase() ==
                  _batchController.text.trim().toLowerCase(),
          orElse: () => <String, dynamic>{},
        );
        _selectedBatchId = _batchId(matched);
        if (_selectedBatchId == null || _selectedBatchId!.isEmpty) {
          final Map<String, dynamic> firstValid = batches.firstWhere(
            (Map<String, dynamic> item) => _batchId(item).isNotEmpty,
            orElse: () => <String, dynamic>{},
          );
          _selectedBatchId = _batchId(firstValid);
        }
        if (_selectedBatchId != null && _selectedBatchId!.isNotEmpty) {
          final Map<String, dynamic> selectedBatch = batches.firstWhere(
            (Map<String, dynamic> item) => _batchId(item) == _selectedBatchId,
            orElse: () => <String, dynamic>{},
          );
          _batchController.text = selectedBatch['name']?.toString() ?? _batchController.text;
        } else {
          _batchController.text = '';
        }
      });
    } catch (_) {}
  }

  Future<void> _onAcademyChanged(String? academyId) async {
    if (academyId == null || academyId == _selectedAcademyId) {
      return;
    }

    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      return;
    }

    try {
      final List<Map<String, dynamic>> batches = await GroundWaleApi.instance
          .listAcademyBatches(ownerId, academyId: academyId);
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedAcademyId = academyId;
        _batches = batches;
        final Map<String, dynamic> firstValid = batches.firstWhere(
          (Map<String, dynamic> item) => _batchId(item).isNotEmpty,
          orElse: () => <String, dynamic>{},
        );
        _selectedBatchId = _batchId(firstValid);
        if ((_selectedBatchId ?? '').isNotEmpty) {
          _batchController.text = firstValid['name']?.toString() ?? '';
        } else {
          _batchController.text = '';
        }
      });
    } catch (_) {}
  }

  Future<void> _pickFeesAmount() async {
    final List<String> options = <String>[
      '1000',
      '1500',
      '2000',
      '2500',
      '3000',
    ];
    final String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF203A43),
          title: const Text('Fees Amount', style: TextStyle(color: Colors.white)),
          contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: options
                  .map(
                    (String value) => ListTile(
                      title: Text(
                        'Rs $value',
                        style: const TextStyle(color: Colors.white),
                      ),
                      onTap: () => Navigator.of(context).pop(value),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
    if (selected != null && mounted) {
      setState(() => _feesController.text = selected);
    }
  }

  Future<void> _pickJoiningDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial =
        DateTime.tryParse(_joiningDateController.text.trim()) ?? now;
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _joiningDateController.text = selected.toIso8601String().split('T').first;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _batchController.dispose();
    _feesController.dispose();
    _joiningDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
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
                          'Edit Student',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel(label: 'Student Name'),
                    const SizedBox(height: 12),
                    _TextFieldBox(controller: _nameController),
                    const SizedBox(height: 24),
                    _FieldLabel(label: 'Phone number'),
                    const SizedBox(height: 12),
                    _TextFieldBox(controller: _phoneController),
                    const SizedBox(height: 24),
                    _FieldLabel(label: 'Select Academy'),
                    const SizedBox(height: 12),
                    _AcademyDropdownField(
                      academies: _academies,
                      selectedAcademyId: _selectedAcademyId,
                      onChanged: _onAcademyChanged,
                    ),
                    const SizedBox(height: 24),
                    _FieldLabel(label: 'Select Batch'),
                    const SizedBox(height: 12),
                    _BatchDropdownField(
                      batches: _batches,
                      selectedBatchId: _selectedBatchId,
                      onChanged: (String? value) {
                        if (value == null) {
                          return;
                        }
                        final Map<String, dynamic> batch = _batches.firstWhere(
                          (Map<String, dynamic> item) => _batchId(item) == value,
                          orElse: () => <String, dynamic>{},
                        );
                        setState(() {
                          _selectedBatchId = value;
                          _batchController.text =
                              batch['name']?.toString() ?? _batchController.text;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const _FieldLabel(label: 'Fees Amount'),
                              const SizedBox(height: 12),
                              _TextFieldBox(
                                controller: _feesController,
                                readOnly: true,
                                onTap: _pickFeesAmount,
                                trailing: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0x99FFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const _FieldLabel(label: 'Joining Date'),
                              const SizedBox(height: 12),
                              _TextFieldBox(
                                controller: _joiningDateController,
                                readOnly: true,
                                onTap: _pickJoiningDate,
                                trailing: const Icon(
                                  Icons.calendar_today_outlined,
                                  color: Color(0x99FFFFFF),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const _FieldLabel(label: 'Fees Status'),
                              const SizedBox(height: 12),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _OptionTile(
                                      label: 'Paid',
                                      selected: _feeStatus == 'Paid',
                                      onTap: () {
                                        setState(() => _feeStatus = 'Paid');
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _OptionTile(
                                      label: 'Pending',
                                      selected: _feeStatus == 'Pending',
                                      onTap: () {
                                        setState(() => _feeStatus = 'Pending');
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _FieldLabel(
                      label: 'Payment Mode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _OptionTile(
                            label: 'UPI',
                            selected: _paymentMode == 'UPI',
                            onTap: () {
                              setState(() => _paymentMode = 'UPI');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OptionTile(
                            label: 'Cash',
                            selected: _paymentMode == 'Cash',
                            onTap: () {
                              setState(() => _paymentMode = 'Cash');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OptionTile(
                            label: 'Card',
                            selected: _paymentMode == 'Card',
                            onTap: () {
                              setState(() => _paymentMode = 'Card');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: <Widget>[
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
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0x1FFFFFFF)),
                        backgroundColor: const Color(0x08FFFFFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
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
    );
  }

  double _parseAmount(String value) {
    final String digits = value.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    return double.tryParse(digits) ?? 0;
  }

  String _dateOnlyString(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _save() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owner session not found')),
      );
      return;
    }
    if (widget.studentId.isEmpty) {
      return;
    }

    final double amount = _parseAmount(_feesController.text);
    final DateTime joinDate =
        _joiningDateController.text.trim().toLowerCase() == 'today'
        ? DateTime.now()
        : DateTime.tryParse(_joiningDateController.text.trim()) ??
              DateTime.now();
    final DateTime joinDateOnly = DateTime(
      joinDate.year,
      joinDate.month,
      joinDate.day,
    );

    setState(() => _isSaving = true);
    try {
      if (_nameController.text.trim().isEmpty || amount < 0 || joinDate.year < 2000) {
        throw Exception('Invalid student details');
      }

      await GroundWaleApi.instance
          .updateAcademyStudent(ownerId, widget.studentId, <String, dynamic>{
            'academyId': _selectedAcademyId,
            'fullName': _nameController.text.trim(),
            'phone': _phoneController.text.trim(),
            if (_selectedBatchId != null && _selectedBatchId!.isNotEmpty)
              'batchId': _selectedBatchId,
            'joinDate': _dateOnlyString(joinDateOnly),
            'monthlyFee': amount,
          });

      final List<Map<String, dynamic>> fees = await GroundWaleApi.instance
          .listAcademyFees(
            ownerId,
            studentId: widget.studentId,
            academyId: _selectedAcademyId,
          );
      if (fees.isNotEmpty) {
        final String feeId = fees.first['_id']?.toString() ?? '';
        if (feeId.isNotEmpty) {
          await GroundWaleApi.instance
              .updateAcademyFee(ownerId, feeId, <String, dynamic>{
                'amount': amount,
                'paidAmount': _feeStatus == 'Paid' ? amount : 0,
                'status': _feeStatus == 'Paid' ? 'paid' : 'pending',
                'paymentMode': _paymentMode,
              });
        }
      } else if (amount > 0) {
        final String monthKey =
            '${joinDateOnly.year}-${joinDateOnly.month.toString().padLeft(2, '0')}';
        await GroundWaleApi.instance.createAcademyFee(ownerId, <String, dynamic>{
          'academyId': _selectedAcademyId,
          'studentId': widget.studentId,
          'monthKey': monthKey,
          'amount': amount,
          'paidAmount': _feeStatus == 'Paid' ? amount : 0,
          'status': _feeStatus == 'Paid' ? 'paid' : 'pending',
          'paymentMode': _paymentMode,
        });
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
}

class _AcademyDropdownField extends StatelessWidget {
  const _AcademyDropdownField({
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
        .map((Map<String, dynamic> academy) {
          return <String, String>{
            'id': _academyId(academy),
            'name': academy['name']?.toString() ?? 'Academy',
          };
        })
        .where((Map<String, String> item) => item['id']!.isNotEmpty)
        .toList();

    final String? normalizedValue = options.any(
      (Map<String, String> item) => item['id'] == selectedAcademyId,
    )
        ? selectedAcademyId
        : null;

    if (options.isEmpty) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          color: const Color(0x0FFFFFFF),
        ),
        alignment: Alignment.centerLeft,
        child: const Text(
          'No academies available',
          style: TextStyle(color: Color(0x99FFFFFF), fontSize: 15),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      key: ValueKey<String>('${normalizedValue ?? 'none'}_${options.length}'),
      initialValue: normalizedValue,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0x99FFFFFF),
      ),
      dropdownColor: const Color(0xFF203A43),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.style});

  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style:
          style ??
          const TextStyle(
            color: Color(0xFFE6F7F4),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
    );
  }
}

class _TextFieldBox extends StatelessWidget {
  const _TextFieldBox({
    required this.controller,
    this.trailing,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final Widget? trailing;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget field = Container(
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0FFFFFFF),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: IgnorePointer(
              ignoring: readOnly,
              child: AppTextField(
                controller: controller,
                readOnly: readOnly,
                onTap: onTap,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  isDense: true,
                ),
              ),
            ),
          ),
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: trailing,
            ),
        ],
      ),
    );

    if (!readOnly) {
      return field;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: field,
    );
  }
}

class _BatchDropdownField extends StatelessWidget {
  const _BatchDropdownField({
    required this.batches,
    required this.selectedBatchId,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> batches;
  final String? selectedBatchId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> options = batches
        .map((Map<String, dynamic> batch) {
          return <String, String>{
            'id': batch['_id']?.toString() ?? batch['id']?.toString() ?? '',
            'name': batch['name']?.toString() ?? 'Batch',
          };
        })
        .where((Map<String, String> item) => item['id']!.isNotEmpty)
        .toList();

    final String? normalizedValue = options.any(
      (Map<String, String> item) => item['id'] == selectedBatchId,
    )
        ? selectedBatchId
        : null;

    if (options.isEmpty) {
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          color: const Color(0x0FFFFFFF),
        ),
        alignment: Alignment.centerLeft,
        child: const Text(
          'No batches available',
          style: TextStyle(color: Color(0x99FFFFFF), fontSize: 15),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      key: ValueKey<String>('${normalizedValue ?? 'none'}_${options.length}'),
      initialValue: normalizedValue,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: Color(0x99FFFFFF),
      ),
      dropdownColor: const Color(0xFF203A43),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF1C333B)
                : const Color(0x1F242424),
          ),
          color: selected ? const Color(0xFF00C9A7) : const Color(0x08FFFFFF),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF242424) : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}


