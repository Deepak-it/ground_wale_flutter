import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ground_wale/core/widgets/app_text_field.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_session.dart';
import '../../../core/api/ground_wale_api.dart';
import '../../../core/utils/base64_image.dart';

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
  late final TextEditingController _paidNowController;

  String? _photoBase64;
  bool _isSaving = false;
  bool _fullAmountPaid = true;
  List<Map<String, dynamic>> _academies = <Map<String, dynamic>>[];
  String? _selectedAcademyId;
  List<Map<String, dynamic>> _batches = <Map<String, dynamic>>[];
  String? _selectedBatchId;
  List<Map<String, dynamic>> _feePlans = <Map<String, dynamic>>[];
  int _selectedFeePlanIndex = 0;

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

  List<Map<String, dynamic>> _batchFeePlans(Map<String, dynamic> batch) {
    final dynamic raw = batch['feePlans'];
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<Map>()
          .map((Map item) => Map<String, dynamic>.from(item))
          .toList();
    }
    final double monthlyFee =
        (batch['monthlyFee'] as num?)?.toDouble() ?? 0;
    if (monthlyFee > 0) {
      return <Map<String, dynamic>>[
        <String, dynamic>{'duration': 'Monthly', 'price': monthlyFee},
      ];
    }
    return <Map<String, dynamic>>[];
  }

  double _planPrice(Map<String, dynamic> plan) {
    final dynamic raw = plan['price'];
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _batchController = TextEditingController(text: 'Morning batch');
    _feesController = TextEditingController();
    _joiningController = TextEditingController(text: 'Today');
    _paidNowController = TextEditingController();
    _loadAcademiesAndBatches();
  }

  Future<void> _pickPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 70,
    );
    if (file == null || !mounted) {
      return;
    }
    final Uint8List bytes = await file.readAsBytes();
    final String base64 = base64Encode(bytes);
    setState(() => _photoBase64 = base64);
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
          _feePlans = _batchFeePlans(selectedBatch);
          _selectedFeePlanIndex = 0;
        } else {
          _batchController.text = '';
          _feesController.text = '';
          _feePlans = <Map<String, dynamic>>[];
          _selectedFeePlanIndex = 0;
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
          _feePlans = _batchFeePlans(firstValid);
          _selectedFeePlanIndex = 0;
        } else {
          _batchController.text = '';
          _feesController.text = '';
          _feePlans = <Map<String, dynamic>>[];
          _selectedFeePlanIndex = 0;
        }
      });
    } catch (_) {}
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

    final double monthlyFee = _feePlans.isNotEmpty
        ? _planPrice(
            _feePlans[_selectedFeePlanIndex.clamp(
              0,
              _feePlans.length - 1,
            )],
          )
        : 0;
    final DateTime joinDate =
        _joiningController.text.trim().toLowerCase() == 'today'
        ? DateTime.now()
        : DateTime.tryParse(_joiningController.text.trim()) ?? DateTime.now();
    final DateTime joinDateOnly = DateTime(
      joinDate.year,
      joinDate.month,
      joinDate.day,
    );

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
            'joinDate': _dateOnlyString(joinDateOnly),
            'monthlyFee': monthlyFee,
            'status': 'active',
            if (_photoBase64 != null && _photoBase64!.isNotEmpty)
              'photoBase64': _photoBase64,
          });

      final String studentId = student['_id']?.toString() ?? '';
      final double paidNow = _fullAmountPaid
          ? monthlyFee
          : _parseAmount(_paidNowController.text);
      final String feeStatus = monthlyFee > 0
          ? (paidNow >= monthlyFee
              ? 'paid'
              : paidNow > 0
              ? 'partial'
              : 'pending')
          : 'paid';
      final String planDuration = _feePlans.isNotEmpty
          ? (_feePlans[_selectedFeePlanIndex.clamp(
                0,
                _feePlans.length - 1,
              )]['duration']
                  ?.toString() ??
              'Monthly')
          : 'Monthly';

      if (studentId.isNotEmpty && monthlyFee > 0) {
        final String monthKey =
            '${joinDateOnly.year}-${joinDateOnly.month.toString().padLeft(2, '0')}';
        await GroundWaleApi.instance.createAcademyFee(ownerId, <String, dynamic>{
          'academyId': _selectedAcademyId,
          'studentId': studentId,
          'monthKey': monthKey,
          'amount': monthlyFee,
          'paidAmount': paidNow.clamp(0, monthlyFee),
          'status': feeStatus,
          'paymentMode': paidNow > 0 ? 'Cash' : '',
          'planDuration': planDuration,
          'subscriptionStartDate': _dateOnlyString(joinDateOnly),
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
    _paidNowController.dispose();
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
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: const Color(0x08FFFFFF),
                          borderRadius: BorderRadius.circular(1000),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _photoBase64 != null && _photoBase64!.isNotEmpty
                            ? Builder(
                                builder: (_) {
                                  final Uint8List? bytes =
                                      decodeBase64ImageBytes(_photoBase64);
                                  return bytes != null
                                      ? Image.memory(
                                          bytes,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(
                                          Icons.person_outline_rounded,
                                          size: 48,
                                          color: Colors.white,
                                        );
                                },
                              )
                            : const Icon(
                                Icons.person_outline_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _photoBase64 != null ? 'Change Photo' : 'Upload Photo',
                        style: const TextStyle(
                          color: Color(0xFF00C9A7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
                    _feePlans = _batchFeePlans(batch);
                    _selectedFeePlanIndex = 0;
                    if (!_fullAmountPaid && _feePlans.isNotEmpty) {
                      final double price = _planPrice(_feePlans[0]);
                      _paidNowController.text =
                          price.toStringAsFixed(price % 1 == 0 ? 0 : 2);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              const _FieldLabel('Fee Plan'),
              const SizedBox(height: 12),
              if (_feePlans.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x1FFFFFFF)),
                    color: const Color(0x0AFFFFFF),
                  ),
                  child: const Text(
                    'Select a batch to see available fee plans',
                    style: TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 14,
                    ),
                  ),
                )
              else
                Column(
                  children: _feePlans
                      .asMap()
                      .entries
                      .map(
                        (MapEntry<int, Map<String, dynamic>> entry) {
                          final int index = entry.key;
                          final Map<String, dynamic> plan = entry.value;
                          final String duration =
                              plan['duration']?.toString() ?? 'Monthly';
                          final double price = _planPrice(plan);
                          final bool selected =
                              _selectedFeePlanIndex == index;
                          return GestureDetector(
                            onTap: () => setState(
                              () {
                                _selectedFeePlanIndex = index;
                                if (!_fullAmountPaid) {
                                  _paidNowController.text =
                                      price.toStringAsFixed(
                                        price % 1 == 0 ? 0 : 2,
                                      );
                                }
                              },
                            ),
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF00C9A7)
                                      : const Color(0x1FFFFFFF),
                                ),
                                color: selected
                                    ? const Color(0x1400C9A7)
                                    : const Color(0x0AFFFFFF),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: selected
                                        ? const Color(0xFF00C9A7)
                                        : Colors.white54,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      duration,
                                      style: TextStyle(
                                        color: selected
                                            ? const Color(0xFF00C9A7)
                                            : Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Rs ${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)}',
                                    style: TextStyle(
                                      color: selected
                                          ? const Color(0xFF00C9A7)
                                          : const Color(0xFFE6F7F4),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                      .toList(),
                ),
              const SizedBox(height: 16),
              // ── Payment section ────────────────────────────────────
              Row(
                children: <Widget>[
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
              GestureDetector(
                onTap: () => setState(() {
                  _fullAmountPaid = !_fullAmountPaid;
                  if (_fullAmountPaid) {
                    _paidNowController.clear();
                  } else {
                    // Pre-fill with the selected plan price
                    if (_feePlans.isNotEmpty) {
                      final double price = _planPrice(
                        _feePlans[_selectedFeePlanIndex.clamp(
                          0,
                          _feePlans.length - 1,
                        )],
                      );
                      _paidNowController.text =
                          price.toStringAsFixed(price % 1 == 0 ? 0 : 2);
                    }
                  }
                }),
                child: Row(
                  children: <Widget>[
                    Icon(
                      _fullAmountPaid
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: _fullAmountPaid
                          ? const Color(0xFF00C9A7)
                          : Colors.white54,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Full amount paid',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_fullAmountPaid) ...<Widget>[
                const SizedBox(height: 12),
                const _FieldLabel('Amount Paid Now'),
                const SizedBox(height: 8),
                _DarkTextField(
                  controller: _paidNowController,
                  hint: 'Rs 0 — enter amount paid today',
                  keyboardType: TextInputType.number,
                ),
              ],
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
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final IconData? trailingIcon;
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


