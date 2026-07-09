import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';

class AcademyAddStudentScreen extends StatefulWidget {
  const AcademyAddStudentScreen({super.key});

  @override
  State<AcademyAddStudentScreen> createState() =>
      _AcademyAddStudentScreenState();
}

class _AcademyAddStudentScreenState extends State<AcademyAddStudentScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _batchController;
  late final TextEditingController _feesController;
  late final TextEditingController _joiningController;
  late final TextEditingController _feesStatusController;

  String _feesStatus = 'Pending';
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

  String _feeTextForBatch(Map<String, dynamic> batch) {
    final double amount = (batch['monthlyFee'] as num?)?.toDouble() ?? 0;
    final String formatted = amount % 1 == 0
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return 'Rs $formatted';
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _batchController = TextEditingController(text: 'Morning batch');
    _feesController = TextEditingController();
    _joiningController = TextEditingController(text: 'Today');
    _feesStatusController = TextEditingController(text: _feesStatus);
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
      if (!mounted) {
        return;
      }

      String? selectedAcademyId = _selectedAcademyId;
      if (selectedAcademyId == null ||
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
        final Map<String, dynamic> matched = batches.firstWhere(
          (Map<String, dynamic> item) =>
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
          _batchController.text =
              selectedBatch['name']?.toString() ?? _batchController.text;
          _feesController.text = _feeTextForBatch(selectedBatch);
        } else {
          _batchController.text = '';
          _feesController.text = '';
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
          _feesController.text = _feeTextForBatch(firstValid);
        } else {
          _batchController.text = '';
          _feesController.text = '';
        }
      });
    } catch (_) {}
  }

  double _parseAmount(String value) {
    final String digits = value.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    return double.tryParse(digits) ?? 0;
  }

  Future<void> _pickJoiningDate() async {
    final DateTime now = DateTime.now();
    final DateTime initial =
        DateTime.tryParse(_joiningController.text.trim()) ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _joiningController.text = picked.toIso8601String().split('T').first;
    });
  }

  Future<void> _pickFeesAmount() async {
    final List<String> options = <String>[
      'Rs 1000',
      'Rs 1500',
      'Rs 2000',
      'Rs 2500',
      'Rs 3000',
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
                        value,
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

  Future<void> _pickFeesStatus() async {
    final String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF203A43),
          title: const Text('Fees Status', style: TextStyle(color: Colors.white)),
          contentPadding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: const Text(
                  'Paid',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.of(context).pop('Paid'),
              ),
              ListTile(
                title: const Text(
                  'Pending',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.of(context).pop('Pending'),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null && mounted) {
      setState(() {
        _feesStatus = selected;
        _feesStatusController.text = selected;
      });
    }
  }

  Future<void> _submit() async {
    final String? ownerId = ApiSession.instance.ownerId;
    if (ownerId == null || ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owner session not found')),
      );
      return;
    }

    final String fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Student name is required')));
      return;
    }

    final Map<String, dynamic>? selectedBatch = _batches
        .where((Map<String, dynamic> batch) => _batchId(batch) == _selectedBatchId)
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (Map<String, dynamic>? _) => true,
          orElse: () => _batches.isEmpty ? null : _batches.first,
        );

    final double monthlyFee = _parseAmount(_feesController.text);
    final DateTime joinDate =
        _joiningController.text.trim().toLowerCase() == 'today'
        ? DateTime.now()
        : DateTime.tryParse(_joiningController.text.trim()) ?? DateTime.now();

    setState(() => _isSaving = true);
    try {
      // if (!hasBatch || monthlyFee < 0 || joinDate.year < 2000) {
      //   throw Exception('Invalid student details');
      // }

      final Map<String, dynamic> student = await GroundWaleApi.instance
          .createAcademyStudent(ownerId, <String, dynamic>{
            'academyId': _selectedAcademyId,
            'fullName': fullName,
            'phone': _phoneController.text.trim(),
            'batchId': selectedBatch == null ? null : _batchId(selectedBatch),
            'batchName': selectedBatch?['name']?.toString() ?? _batchController.text.trim(),
            'joinDate': joinDate.toIso8601String(),
            'monthlyFee': monthlyFee,
            'status': 'active',
          });

      final String studentId = student['_id']?.toString() ?? '';
      if (studentId.isNotEmpty && monthlyFee > 0) {
        final DateTime now = DateTime.now();
        final String monthKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}';
        final bool paid = _feesStatus.toLowerCase() == 'paid';
        await GroundWaleApi.instance.createAcademyFee(ownerId, <String, dynamic>{
          'academyId': _selectedAcademyId,
          'studentId': studentId,
          'monthKey': monthKey,
          'amount': monthlyFee,
          'paidAmount': paid ? monthlyFee : 0,
          'status': paid ? 'paid' : 'pending',
          'paymentMode': paid ? 'UPI' : '',
        });
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Student added')));
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _batchController.dispose();
    _feesController.dispose();
    _joiningController.dispose();
    _feesStatusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    'Add Student',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0x08FFFFFF),
                        borderRadius: BorderRadius.circular(1000),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Upload Photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _FieldLabel('Student Name'),
              const SizedBox(height: 12),
              _DarkTextField(
                controller: _nameController,
                hint: 'Enter full name',
              ),
              const SizedBox(height: 24),
              const _FieldLabel('Phone number'),
              const SizedBox(height: 12),
              _DarkTextField(
                controller: _phoneController,
                hint: '+91   Enter mobile number',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              const _FieldLabel('Select Academy'),
              const SizedBox(height: 12),
              _AcademyDropdownField(
                academies: _academies,
                selectedAcademyId: _selectedAcademyId,
                onChanged: _onAcademyChanged,
              ),
              const SizedBox(height: 24),
              const _FieldLabel('Select Batch'),
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
                    _feesController.text = _feeTextForBatch(batch);
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const _FieldLabel('Fees Amount'),
                        const SizedBox(height: 12),
                        _DarkPickerField(
                          controller: _feesController,
                          trailingIcon: Icons.keyboard_arrow_down_rounded,
                          readOnly: true,
                          onTap: _pickFeesAmount,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const _FieldLabel('Joining Date'),
                        const SizedBox(height: 12),
                        _DarkPickerField(
                          controller: _joiningController,
                          trailingIcon: Icons.calendar_month_outlined,
                          readOnly: true,
                          onTap: _pickJoiningDate,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const _FieldLabel('Fees Status'),
                        const SizedBox(height: 12),
                        _DarkPickerField(
                          controller: _feesStatusController,
                          trailingIcon: Icons.keyboard_arrow_down_rounded,
                          backgroundColor: const Color(0x0FFFFFFF),
                          readOnly: true,
                          onTap: _pickFeesStatus,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 26),
                        SizedBox(
                          height: 44,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _feesStatus = _feesStatus == 'Pending'
                                    ? 'Paid'
                                    : 'Pending';
                                _feesStatusController.text = _feesStatus;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _feesStatus == 'Pending'
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _feesStatus,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
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
                          'Add Student',
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
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0x08FFFFFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
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
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

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

class _DarkTextField extends StatelessWidget {
  const _DarkTextField({
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: const Color(0x0FFFFFFF),
      ),
      child: AppTextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0x99FFFFFF),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      ),
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

  String _batchId(Map<String, dynamic> batch) {
    return batch['_id']?.toString() ?? batch['id']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> options = batches
        .map((Map<String, dynamic> batch) {
          return <String, String>{
            'id': _batchId(batch),
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

class _DarkPickerField extends StatelessWidget {
  const _DarkPickerField({
    required this.controller,
    this.trailingIcon,
    this.backgroundColor = const Color(0x0FFFFFFF),
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final IconData? trailingIcon;
  final Color backgroundColor;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget field = Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1FFFFFFF)),
        color: backgroundColor,
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
                  isDense: true,
                ),
              ),
            ),
          ),
          if (trailingIcon != null)
            Icon(trailingIcon, color: const Color(0x99FFFFFF), size: 18),
        ],
      ),
    );

    if (!readOnly) {
      return field;
    }

    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: field);
  }
}


